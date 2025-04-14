process SAMTOOLS_COUNT {
    tag "$meta.id"

    cpus = 1
    memory = { 512.MB * task.attempt }

    input:
        tuple val(meta), path(cram)

    output:
        tuple val(meta), stdout, emit: count

    script:
        def args = task.ext.args ?: ''
        """
        samtools \\
            view -c \\
            --threads ${task.cpus} \\
            $cram \\
            $args
        """
}
