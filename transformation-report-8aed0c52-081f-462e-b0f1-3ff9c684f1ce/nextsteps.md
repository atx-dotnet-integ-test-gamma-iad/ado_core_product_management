# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL targets unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages, missing versions, or compatibility issues.

### 3. Build the Solution
Perform a clean build to confirm there are no issues beyond what the error log captured:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416, etc.).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failing or skipped tests. Investigate any tests that were previously passing but now fail.

### 5. Check for Windows-Specific API Usage
Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Look for `CA1416` warnings indicating platform-specific API calls. Wrap these with platform guards where necessary:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is listed as the most independent (and therefore foundational) project in the solution, manually inspect its `.csproj` for the following:

- Any remaining `<HintPath>` references pointing to local or GAC assemblies that may not exist cross-platform.
- Any `<Reference>` elements that should be replaced with NuGet `<PackageReference>` entries.
- Any `<PackageReference>` entries pointing to packages that have known .NET compatibility issues.

### 7. Validate Runtime Behavior
Run the application against a representative set of inputs or scenarios to confirm runtime behavior matches expectations from the legacy version. Pay particular attention to:

- Database connectivity (if ADO.NET is in use, given the `AdoCore` project name).
- File I/O paths, which may use backslashes or absolute paths that are not cross-platform compatible. Use `Path.Combine` and `Path.DirectorySeparatorChar` where needed.
- Configuration loading, ensuring `app.config` references have been migrated to `appsettings.json` or equivalent if applicable.

### 8. Check for `app.config` / `web.config` Remnants
If the legacy project used `app.config` or `web.config`, verify those settings have been properly migrated to the .NET configuration system:

```csharp
IConfiguration config = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();
```

Remove any `System.Configuration.ConfigurationManager` usage that may not behave as expected in cross-platform .NET, or add the `System.Configuration.ConfigurationManager` NuGet package if that dependency must be retained.