#pragma once

#include <qcolor.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>

class BlobShape;
class BlobInvertedRect;

class BlobGroup : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal smoothing READ smoothing WRITE setSmoothing NOTIFY smoothingChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(bool cornerFill READ cornerFill WRITE setCornerFill NOTIFY cornerFillChanged)
    // Chamfer mode: corner radii become 45-degree bevels and blends become chamfers
    Q_PROPERTY(bool chamfer READ chamfer WRITE setChamfer NOTIFY chamferChanged)
    // Scanline overlay strength (0 = off), drawn in screen space so lines align across shapes
    Q_PROPERTY(qreal scanlines READ scanlines WRITE setScanlines NOTIFY scanlinesChanged)

public:
    explicit BlobGroup(QObject* parent = nullptr);
    ~BlobGroup() override;

    qreal smoothing() const { return m_smoothing; }

    void setSmoothing(qreal s);

    QColor color() const { return m_color; }

    void setColor(const QColor& c);

    bool cornerFill() const { return m_cornerFill; }

    void setCornerFill(bool e);

    bool chamfer() const { return m_chamfer; }

    void setChamfer(bool c);

    qreal scanlines() const { return m_scanlines; }

    void setScanlines(qreal s);

    // A chamfer blend reaches further than a circular one (up to ~1.71x smoothing)
    qreal blendReach() const { return m_chamfer ? m_smoothing * 1.75 : m_smoothing; }

    void addShape(BlobShape* shape);
    void removeShape(BlobShape* shape);

    void setInvertedRect(BlobInvertedRect* rect);
    void clearInvertedRect(BlobInvertedRect* rect);

    const QList<BlobShape*>& shapes() const { return m_shapes; }

    BlobInvertedRect* invertedRect() const { return m_invertedRect; }

    void markDirty();
    void markShapeDirty(BlobShape* source);
    void ensurePhysicsUpdated();

signals:
    void smoothingChanged();
    void colorChanged();
    void cornerFillChanged();
    void chamferChanged();
    void scanlinesChanged();

private:
    qreal m_smoothing = 32.0;
    QColor m_color{ 0x44, 0x88, 0xff };
    bool m_cornerFill = true;
    bool m_chamfer = false;
    qreal m_scanlines = 0;
    QList<BlobShape*> m_shapes;
    BlobInvertedRect* m_invertedRect = nullptr;
    bool m_physicsUpdated = false;
};
